"""Shared slowapi limiter instance. Imported by both main.py (to register
the exception handler / middleware) and any router that needs per-route
limits (currently app/routes/ai.py), avoiding a circular import through
main.py.
"""
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
