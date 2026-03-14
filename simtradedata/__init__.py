"""
SimTradeData - Download market data and store in DuckDB with Parquet export

This package fetches data from BaoStock, converts it to PTrade-compatible
format, stores in DuckDB for incremental updates, and exports to Parquet.
"""

__version__ = "0.2.0"

__all__ = [
    "BaoStockFetcher",
    "DataConverter",
    "DuckDBWriter",
]


def __getattr__(name: str):
    if name == "BaoStockFetcher":
        from simtradedata.fetchers.baostock_fetcher import BaoStockFetcher
        return BaoStockFetcher
    if name == "DataConverter":
        from simtradedata.converters.data_converter import DataConverter
        return DataConverter
    if name == "DuckDBWriter":
        from simtradedata.writers.duckdb_writer import DuckDBWriter
        return DuckDBWriter
    raise AttributeError("module 'simtradedata' has no attribute %r" % name)
