"""Tests for BaseFetcher resilience integration (cooldown, circuit breaker, monitor)."""

import pytest

from simtradedata.fetchers.base_fetcher import BaseFetcher
from simtradedata.resilience.circuit_breaker import CircuitBreaker


class DummyFetcher(BaseFetcher):
    """Minimal concrete subclass for testing BaseFetcher resilience."""

    source_name = "test_source"

    def _do_login(self):
        pass

    def _do_logout(self):
        pass


@pytest.mark.unit
class TestBaseFetcherResilience:
    """Tests for resilience integration in BaseFetcher._make_request."""

    def setup_method(self):
        self.fetcher = DummyFetcher()
        # Reset global singleton state so tests are independent.
        self.fetcher._cooldown._sources.clear()
        self.fetcher._monitor._stats.clear()
        self.fetcher._circuit_breaker = CircuitBreaker("test_source")

    def test_successful_request(self):
        result = self.fetcher._make_request(lambda: "ok")
        assert result == "ok"

    def test_records_success_in_monitor(self):
        self.fetcher._make_request(lambda: "ok")
        stats = self.fetcher._monitor.get_stats("test_source")
        assert stats["successful"] == 1

    def test_records_failure_in_monitor(self):
        with pytest.raises(ValueError):
            self.fetcher._make_request(self._raise_value_error)
        stats = self.fetcher._monitor.get_stats("test_source")
        assert stats["failed"] == 1

    def test_skips_when_in_cooldown(self):
        self.fetcher._cooldown.record_failure("test_source", "timeout")
        result = self.fetcher._make_request(lambda: "should not run")
        assert result is None

    def test_skips_when_circuit_open(self):
        for _ in range(5):
            self.fetcher._circuit_breaker.record_failure()
        result = self.fetcher._make_request(lambda: "should not run")
        assert result is None

    # -- helpers --

    @staticmethod
    def _raise_value_error():
        raise ValueError("test error")
