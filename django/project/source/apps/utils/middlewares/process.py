# -*- coding:utf-8 -*-
"""
演示中间件调用过程而创建的三个中间件
"""

from django.utils.deprecation import MiddlewareMixin


class StepOneMiddleware(MiddlewareMixin):
    """
    第一个Middleware
    """
    def process_request(self, request):
        print("Step One Middleware process_request running...")

    def process_response(self, request, response):
        print("Step One Middleware process_response running...")


class StepTwoMiddleware(MiddlewareMixin):
    """
    第二个Middleware
    """
    def process_request(self, request):
        print("Step Two Middleware process_request running...")

    def process_response(self, request, response):
        print("Step Two Middleware process_response running...")


class StepThreeMiddleware(MiddlewareMixin):
    """
    第三个Middleware
    """
    def process_request(self, request):
        print("Step Three Middleware process_request running...")

    def process_response(self, request, response):
        print("Step Three Middleware process_response running...")
