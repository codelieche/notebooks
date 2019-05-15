# Django相关文章

## 目录
- [基础](./base/)
    1. [项目准备](./base/01-项目准备.md)
    2. [settings基本配置](.base/02-settings基本配置.md)
- [Middleware](./middleware)
    1. [middleware的调用过程一](./middleware/01-中间件的调用过程01.md)
    1. [middleware的调用过程二](./middleware/01-中间件的调用过程02.md)

## 项目准备
- 安装好[pyenv](https://github.com/pyenv/pyenv)
- 安装好3.7.0: `pyenv install 3.7.0`
- 设置虚拟环境：`pyenv virtualenv 3.7.0 env_django && pyenv local env_django`
- 安装Django：`pip install Django==2.2.1`
- 创建项目：`cd project && django-admin startproject codelieche`
- 修改目录：`mv codelieche source`

```bash
(env_django) ➜  django git:(master) ✗ tree
.
├── README.md
└── project
    └── source
        ├── codelieche
        │   ├── __init__.py
        │   ├── settings.py
        │   ├── urls.py
        │   └── wsgi.py
        ├── manage.py
        └── requirements.txt
```
