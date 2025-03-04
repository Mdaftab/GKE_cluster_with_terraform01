#!/usr/bin/env python3

import os
import re
import json
import subprocess
from datetime import datetime
import hcl2
import yaml
from typing import Dict, List, Any

class ProjectAnalyzer:
    def __init__(self, project_root: str):
        self.project_root = project_root
        self.structure = {}
        self.terraform_modules = {}
        self.kubernetes_resources = {}
        
    def analyze_terraform_file(self, file_path: str) -> Dict[str, Any]:
        """Analyze a Terraform file and extract its structure."""
        try:
            with open(file_path, 'r') as f:
                content = f.read()
                parsed = hcl2.loads(content)
                return parsed
        except Exception as e:
            print(f"Warning: Could not parse Terraform file {file_path}: {e}")
            return {}

    def analyze_kubernetes_manifests(self, file_path: str) -> Dict[str, Any]:
        """Analyze Kubernetes manifest files."""
        try:
            with open(file_path, 'r') as f:
                content = yaml.safe_load_all(f)
                return list(content)
        except Exception as e:
            print(f"Warning: Could not parse Kubernetes manifest {file_path}: {e}")
            return {}

    def get_terraform_outputs(self, env_dir: str) -> Dict[str, Any]:
        """Get Terraform outputs for an environment."""
        try:
            result = subprocess.run(
                ['terraform', 'output', '-json'],
                cwd=env_dir,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                return json.loads(result.stdout)
            return {}
        except Exception:
            return {}

    def analyze_project(self):
        """Analyze the entire project structure."""
        # Analyze Terraform modules
        for root, _, files in os.walk(os.path.join(self.project_root, "modules")):
            for file in files:
                if file.endswith('.tf'):
                    file_path = os.path.join(root, file)
                    module_name = os.path.basename(os.path.dirname(file_path))
                    if module_name not in self.terraform_modules:
                        self.terraform_modules[module_name] = []
                    self.terraform_modules[module_name].append(
                        self.analyze_terraform_file(file_path)
                    )

        # Analyze Kubernetes manifests
        k8s_dir = os.path.join(self.project_root, "kubernetes/manifests")
        if os.path.exists(k8s_dir):
            for file in os.listdir(k8s_dir):
                if file.endswith(('.yaml', '.yml')):
                    file_path = os.path.join(k8s_dir, file)
                    self.kubernetes_resources[file] = self.analyze_kubernetes_manifests(file_path)

    def generate_module_documentation(self) -> str:
        """Generate documentation for Terraform modules."""
        doc = "## 🏗 Terraform Modules\n\n"
        for module, configs in self.terraform_modules.items():
            doc += f"### {module}\n\n"
            
            # Extract resources
            resources = []
            variables = []
            outputs = []
            
            for config in configs:
                if 'resource' in config:
                    if isinstance(config['resource'], dict):
                        for resource_type, instances in config['resource'].items():
                            for instance in instances:
                                resources.append(f"- `{resource_type}.{list(instance.keys())[0]}`")
                    elif isinstance(config['resource'], list):
                        for resource_item in config['resource']:
                            if isinstance(resource_item, dict):
                                resource_type = list(resource_item.keys())[0]
                                instances = resource_item[resource_type]
                                if isinstance(instances, list):
                                    for instance in instances:
                                        if isinstance(instance, dict):
                                            instance_name = list(instance.keys())[0]
                                            resources.append(f"- `{resource_type}.{instance_name}`")
                
                if 'variable' in config:
                    if isinstance(config['variable'], dict):
                        for var_name, var_config in config['variable'].items():
                            var_type = var_config.get('type', 'any')
                            variables.append(f"- `{var_name}` ({var_type})")
                    elif isinstance(config['variable'], list):
                        for var_item in config['variable']:
                            if isinstance(var_item, dict):
                                var_name = list(var_item.keys())[0]
                                var_config = var_item[var_name]
                                var_type = var_config.get('type', 'any')
                                variables.append(f"- `{var_name}` ({var_type})")
                
                if 'output' in config:
                    if isinstance(config['output'], dict):
                        for output_name in config['output'].keys():
                            outputs.append(f"- `{output_name}`")
                    elif isinstance(config['output'], list):
                        for output_item in config['output']:
                            if isinstance(output_item, dict):
                                output_name = list(output_item.keys())[0]
                                outputs.append(f"- `{output_name}`")
            
            if resources:
                doc += "**Resources:**\n" + "\n".join(resources) + "\n\n"
            if variables:
                doc += "**Variables:**\n" + "\n".join(variables) + "\n\n"
            if outputs:
                doc += "**Outputs:**\n" + "\n".join(outputs) + "\n\n"
        
        return doc

    def generate_kubernetes_documentation(self) -> str:
        """Generate documentation for Kubernetes resources."""
        doc = "## 🚢 Kubernetes Resources\n\n"
        
        for file, resources in self.kubernetes_resources.items():
            doc += f"### {file}\n\n"
            for resource in resources:
                if isinstance(resource, dict):
                    kind = resource.get('kind', 'Unknown')
                    name = resource.get('metadata', {}).get('name', 'unnamed')
                    doc += f"- `{kind}/{name}`\n"
            doc += "\n"
        
        return doc

    def generate_infrastructure_diagram(self) -> str:
        """Generate infrastructure diagram using terraform-visual."""
        try:
            env_dir = os.path.join(self.project_root, "environments/dev")
            diagram_dir = os.path.join(self.project_root, "docs/diagrams")
            os.makedirs(diagram_dir, exist_ok=True)
            
            # Generate diagram using terraform-visual
            subprocess.run(
                ['terraform-visual', '--dir', env_dir, '--output', os.path.join(diagram_dir, 'infrastructure.png')],
                check=True
            )
            
            return "## 📊 Infrastructure Diagram\n\n![Infrastructure Diagram](docs/diagrams/infrastructure.png)\n\n"
        except Exception as e:
            print(f"Warning: Could not generate infrastructure diagram: {e}")
            return ""

    def update_readme(self):
        """Update the project's README.md file."""
        readme_path = os.path.join(self.project_root, "README.md")
        
        # Read existing README content
        try:
            with open(readme_path, 'r') as f:
                content = f.read()
        except FileNotFoundError:
            content = "# GKE Cluster with Terraform\n\n"
        
        # Preserve the content before the auto-generated section
        if "<!-- BEGIN AUTO-GENERATED -->" in content:
            content = content.split("<!-- BEGIN AUTO-GENERATED -->")[0]
        
        # Generate new documentation
        self.analyze_project()
        
        new_content = content.rstrip() + "\n\n"
        new_content += "<!-- BEGIN AUTO-GENERATED -->\n"
        new_content += "> ⚠️ This section is automatically generated. Do not modify manually.\n"
        new_content += f"> Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        
        # Add infrastructure diagram
        new_content += self.generate_infrastructure_diagram()
        
        # Add module documentation
        new_content += self.generate_module_documentation()
        
        # Add Kubernetes documentation
        new_content += self.generate_kubernetes_documentation()
        
        # Write updated README
        with open(readme_path, 'w') as f:
            f.write(new_content)

if __name__ == "__main__":
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    analyzer = ProjectAnalyzer(project_root)
    analyzer.update_readme()
