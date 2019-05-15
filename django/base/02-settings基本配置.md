## Django项目常用配置

### 把自定义的app全部放入apps目录中
> 把代码根目录下的apps目录加入到PATH路径即可。

```diff
 import os
+import sys
 
 # Build paths inside the project like this: os.path.join(BASE_DIR, ...)
 BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
-
+# 把apps添加到path路径中，app统一放apps中
+sys.path.append(os.path.join(BASE_DIR, "apps"))
```
- 创建目录：`mkdir apps`
- settings.py
```python
import os
import sys

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# 把apps添加到path路径中，app统一放apps中
sys.path.append(os.path.join(BASE_DIR, "apps"))
```

### 设置tempates目录
- 创建目录：`mkdir templates`

```diff
TEMPLATES = [
     {
         'BACKEND': 'django.template.backends.django.DjangoTemplates',
-        'DIRS': [],
+        'DIRS': [os.path.join(BASE_DIR, "templates")],
         'APP_DIRS': True,
         'OPTIONS': {
             'context_processors': [
```