# -*- coding:utf-8 -*-
# from django.shortcuts import render
from django.http.response import Http404


class PageIndex:

    def __init__(self, request):
        self.request = request

    def render(self):
        # return render(request=self.request, template_name="index.html")
        raise Http404()


def page_index(request):
    print("index view function running...")
    # raise Http404()
    # return render(request=request, template_name="index.html")
    instance = PageIndex(request)
    return instance

