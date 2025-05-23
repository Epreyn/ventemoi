#!/usr/bin/env python3
import os
import sys
import re

def to_pascal_case(name):
    parts = re.split(r'[^0-9a-zA-Z]+', name)
    parts = [p for p in parts if p]
    return ''.join([p.capitalize() for p in parts])

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <nom_fonctionnalité>")
    sys.exit(1)

screen_name = sys.argv[1]
base_name   = screen_name.lower()             
dir_name    = base_name

base_screens_dir = "lib/features"
os.makedirs(base_screens_dir, exist_ok=True)

base_dir = os.path.join(base_screens_dir, dir_name)
subdirs = ["view", "controllers", "widget", "models"]
for sub in subdirs:
    os.makedirs(os.path.join(base_dir, sub), exist_ok=True)

pascal_name      = to_pascal_case(base_name) 
screen_class     = pascal_name        
controller_class = pascal_name + "Controller"

view_content = f"""import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/{base_name}_controller.dart';

class {screen_class} extends StatelessWidget {{
  const {screen_class}({{
    Key? key,
  }}) : super(key: key);

  @override
  Widget build(BuildContext context) {{
    {controller_class} cc = Get.put({controller_class}());
    return Placeholder();
  }}
}}
"""

controller_content = f"""import 'package:flutter/material.dart';
import 'package:get/get.dart';

class {controller_class} extends GetxController {{
  
}}
"""

view_file_path = os.path.join(base_dir, "view", f"{base_name}.dart")
ctrl_file_path = os.path.join(base_dir, "controllers", f"{base_name}_controller.dart")
with open(view_file_path, "w") as f:
    f.write(view_content)
with open(ctrl_file_path, "w") as f:
    f.write(controller_content)

print(f"Structure de la fonctionnalité '{screen_name}' créée dans {os.path.join(base_screens_dir, dir_name)}")