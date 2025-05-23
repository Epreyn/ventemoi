#!/usr/bin/env python3
import os
import sys
import re

def to_pascal_case(name):
    # Sépare le nom par les séparateurs non-alphanumériques (underscore, tiret, etc.)
    parts = re.split(r'[^0-9a-zA-Z]+', name)
    parts = [p for p in parts if p]  # ignore les parties vides
    # Met chaque partie en PascalCase (Première lettre en majuscule)
    return ''.join([p.capitalize() for p in parts])

# Vérifie la présence d'un argument (nom de l'écran)
if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <nom_ecran>")
    sys.exit(1)

screen_name = sys.argv[1]
base_name   = screen_name.lower()              # ex: "admin_users"
dir_name    = base_name + "_screen"            # ex: "admin_users_screen"

# Crée le dossier de base "screens" s'il n'existe pas
base_screens_dir = "lib/screens"
os.makedirs(base_screens_dir, exist_ok=True)

# Crée les sous-dossiers (view, controllers, widget, models)
base_dir = os.path.join(base_screens_dir, dir_name)
subdirs = ["view", "controllers", "widget", "models"]
for sub in subdirs:
    os.makedirs(os.path.join(base_dir, sub), exist_ok=True)

# Génère les noms de classes en PascalCase
pascal_name      = to_pascal_case(base_name)          # ex: "admin_users" -> "AdminUsers"
screen_class     = pascal_name + "Screen"             # ex: "AdminUsersScreen"
controller_class = pascal_name + "ScreenController"   # ex: "AdminUsersScreenController"

# Contenu du fichier view/<screen>_screen.dart
view_content = f"""import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/{base_name}_screen_controller.dart';

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

# Contenu du fichier controllers/<screen>_screen_controller.dart
controller_content = f"""import 'package:flutter/material.dart';
import 'package:get/get.dart';

class {controller_class} extends GetxController {{
  
}}
"""

# Création des fichiers avec le contenu prédéfini
view_file_path = os.path.join(base_dir, "view", f"{base_name}_screen.dart")
ctrl_file_path = os.path.join(base_dir, "controllers", f"{base_name}_screen_controller.dart")
with open(view_file_path, "w") as f:
    f.write(view_content)
with open(ctrl_file_path, "w") as f:
    f.write(controller_content)

print(f"Structure de l'écran '{screen_name}' créée dans {os.path.join(base_screens_dir, dir_name)}")