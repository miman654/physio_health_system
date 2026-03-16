# token黑名单管理
import time
from typing import Set, Dict
import threading


class TokenBlacklist:
    """简单的内存黑名单管理（生产环境建议用Redis）"""

    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance.blacklist: Dict[str, float] = {}  # token -> 过期时间
        return cls._instance

    def add(self, token: str, expire_time: float):
        """将token加入黑名单"""
        self.blacklist[token] = expire_time
        self._clean_expired()

    def is_blacklisted(self, token: str) -> bool:
        """检查token是否在黑名单中"""
        self._clean_expired()
        return token in self.blacklist

    def _clean_expired(self):
        """清理过期的token"""
        now = time.time()
        expired = [token for token, exp in self.blacklist.items() if exp <= now]
        for token in expired:
            del self.blacklist[token]


# 全局黑名单实例
blacklist = TokenBlacklist()
