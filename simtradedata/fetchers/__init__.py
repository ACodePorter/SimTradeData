"""Fetchers package"""

from simtradedata.fetchers.baostock_fetcher import BaoStockFetcher
from simtradedata.fetchers.eastmoney_fetcher import EastMoneyFetcher
from simtradedata.fetchers.mootdx_affair_fetcher import MootdxAffairFetcher
from simtradedata.fetchers.mootdx_fetcher import MootdxFetcher
from simtradedata.fetchers.mootdx_unified_fetcher import MootdxUnifiedFetcher
from simtradedata.fetchers.yfinance_fetcher import YFinanceFetcher

__all__ = [
    "BaoStockFetcher",
    "EastMoneyFetcher",
    "MootdxFetcher",
    "MootdxAffairFetcher",
    "MootdxUnifiedFetcher",
    "YFinanceFetcher",
]
