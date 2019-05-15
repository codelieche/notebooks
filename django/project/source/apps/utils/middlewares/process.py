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
        print("\nStep One Middleware process_request running...")

    def process_view(self, request, view_func, view_args, view_kwargs):
        print("\nStep One Middleware process_view running......")

    def process_template_response(self, request, response):
        print("Step One Middleware process_template_response running...\n")
        return response

    def process_exception(self, request, exception):
        print("Step One Middleware process_exception running...\n")

    def process_response(self, request, response):
        print("Step One Middleware process_response running...\n")
        return response


class StepTwoMiddleware(MiddlewareMixin):
    """
    第二个Middleware
    """
    def process_request(self, request):
        print("Step Two Middleware process_request running...")

    def process_view(self, request, view_func, view_args, view_kwargs):
        print("Step Two Middleware process_view running......")

    def process_template_response(self, request, response):
        print("Step Two Middleware process_template_response running...")
        return response

    def process_exception(self, request, exception):
        print("Step Two Middleware process_exception running...")

    def process_response(self, request, response):
        print("Step Two Middleware process_response running...")
        return response


class StepThreeMiddleware(MiddlewareMixin):
    """
    第三个Middleware
    """
    def process_request(self, request):
        print("Step Three Middleware process_request running...")

    def process_view(self, request, view_func, view_args, view_kwargs):
        print("Step Three Middleware process_view running......\n")

    def process_template_response(self, request, response):
        print("\nStep Three Middleware process_template_response running...")
        return response

    def process_exception(self, request, exception):
        print("Step Three Middleware process_exception running...")

    def process_response(self, request, response):
        print("Step Three Middleware process_response running...")
        return response

