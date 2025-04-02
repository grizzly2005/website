# Copyright 2025 tatam
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# website/app/monitoring/logging.py
import logging
import sys
import re
from loguru import logger
import time
from functools import wraps

class PerformanceLogger:
    @staticmethod
    def mask_sensitive_data(record):
        """Masquer les données sensibles"""
        sensitive_patterns = [
            r'password',
            r'secret',
            r'token',
            r'key'
        ]
        
        for pattern in sensitive_patterns:
            if re.search(pattern, record['message'], re.IGNORECASE):
                record['message'] = re.sub(r'(\w+)=\w+', r'\1=***MASKED***', record['message'])
        
        return record

    @staticmethod
    def configure_logging():
        # Supprimer les loggers par défaut
        logger.remove()
        
        # Configuration console
        logger.add(
            sys.stderr, 
            level="INFO",
            format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
                   "<level>{level: <8}</level> | "
                   "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>",
            filter=PerformanceLogger.mask_sensitive_data
        )
        
        # Logging fichier
        logger.add(
            "logs/app_{time}.log", 
            rotation="10 MB",
            level="INFO",
            filter=PerformanceLogger.mask_sensitive_data
        )
        
        return logger

    @staticmethod
    def log_performance(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            logger = PerformanceLogger.configure_logging()
            start_time = time.time()
            
            try:
                result = await func(*args, **kwargs)
                execution_time = time.time() - start_time
                
                logger.info(
                    f"Function {func.__name__} "
                    f"executed in {execution_time:.4f} seconds"
                )
                
                return result
            except Exception as e:
                logger.error(f"Error in {func.__name__}: {e}")
                raise
        return wrapper