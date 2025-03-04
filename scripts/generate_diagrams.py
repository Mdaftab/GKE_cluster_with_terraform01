#!/usr/bin/env python3

import os
import json
import subprocess
from typing import Dict, List, Any
import hcl2
import yaml
from datetime import datetime

class InfrastructureDiagramGenerator:
    def __init__(self, project_root: str):
        self.project_root = project_root
        self.terraform_modules = {}
        self.kubernetes_resources = {}
        
    def parse_terraform_file(self, file_path: str) -> Dict[str, Any]:
        """Parse a Terraform file and extract its structure."""
        try:
            with open(file_path, 'r') as f:
                return hcl2.loads(f.read())
        except Exception as e:
            print(f"Warning: Could not parse Terraform file {file_path}: {e}")
            return {}

    def analyze_terraform_modules(self):
        """Analyze all Terraform modules in the project."""
        modules_dir = os.path.join(self.project_root, "modules")
        for module in os.listdir(modules_dir):
            module_path = os.path.join(modules_dir, module)
            if os.path.isdir(module_path):
                self.terraform_modules[module] = {
                    'resources': [],
                    'variables': [],
                    'outputs': []
                }
                
                for file in os.listdir(module_path):
                    if file.endswith('.tf'):
                        config = self.parse_terraform_file(os.path.join(module_path, file))
                        
                        # Extract resources
                        if 'resource' in config:
                            if isinstance(config['resource'], dict):
                                for resource_type, instances in config['resource'].items():
                                    for instance in instances:
                                        self.terraform_modules[module]['resources'].append(
                                            f"{resource_type}.{list(instance.keys())[0]}"
                                        )
                            elif isinstance(config['resource'], list):
                                for resource_item in config['resource']:
                                    if isinstance(resource_item, dict):
                                        # Each item should be a dict with a single key being the resource type
                                        resource_type = list(resource_item.keys())[0]
                                        instances = resource_item[resource_type]
                                        if isinstance(instances, list):
                                            for instance in instances:
                                                if isinstance(instance, dict):
                                                    instance_name = list(instance.keys())[0]
                                                    self.terraform_modules[module]['resources'].append(
                                                        f"{resource_type}.{instance_name}"
                                                    )
                        
                        # Extract variables
                        if 'variable' in config:
                            if isinstance(config['variable'], dict):
                                for var_name, var_config in config['variable'].items():
                                    self.terraform_modules[module]['variables'].append(var_name)
                            elif isinstance(config['variable'], list):
                                for var_item in config['variable']:
                                    if isinstance(var_item, dict):
                                        # Each item should be a dict with a single key being the variable name
                                        var_name = list(var_item.keys())[0]
                                        self.terraform_modules[module]['variables'].append(var_name)
                        
                        # Extract outputs
                        if 'output' in config:
                            if isinstance(config['output'], dict):
                                for output_name in config['output'].keys():
                                    self.terraform_modules[module]['outputs'].append(output_name)
                            elif isinstance(config['output'], list):
                                for output_item in config['output']:
                                    if isinstance(output_item, dict):
                                        # Each item should be a dict with a single key being the output name
                                        output_name = list(output_item.keys())[0]
                                        self.terraform_modules[module]['outputs'].append(output_name)

    def analyze_kubernetes_resources(self):
        """Analyze Kubernetes manifest files."""
        k8s_dir = os.path.join(self.project_root, "kubernetes/manifests")
        if os.path.exists(k8s_dir):
            for file in os.listdir(k8s_dir):
                if file.endswith(('.yaml', '.yml')):
                    with open(os.path.join(k8s_dir, file), 'r') as f:
                        try:
                            resources = list(yaml.safe_load_all(f))
                            self.kubernetes_resources[file] = [
                                {
                                    'kind': r.get('kind', 'Unknown'),
                                    'name': r.get('metadata', {}).get('name', 'unnamed')
                                }
                                for r in resources if isinstance(r, dict)
                            ]
                        except Exception as e:
                            print(f"Warning: Could not parse Kubernetes file {file}: {e}")

    def generate_mermaid_diagram(self) -> str:
        """Generate a Mermaid diagram representing the infrastructure."""
        mermaid = [
            "```mermaid",
            "graph TB",
            "    subgraph Infrastructure",
            "    A[GKE Cluster] --> B[VPC Network]",
        ]
        
        # Add Terraform modules
        for module, details in self.terraform_modules.items():
            mermaid.append(f"    subgraph {module}")
            for resource in details['resources']:
                resource_id = f"{module}_{resource}".replace('.', '_').replace('-', '_')
                mermaid.append(f"        {resource_id}[{resource}]")
            mermaid.append("    end")
        
        # Add Kubernetes resources
        if self.kubernetes_resources:
            mermaid.append("    subgraph Kubernetes")
            for file, resources in self.kubernetes_resources.items():
                for resource in resources:
                    resource_id = f"k8s_{resource['kind']}_{resource['name']}".replace('-', '_')
                    mermaid.append(f"        {resource_id}[{resource['kind']}/{resource['name']}]")
            mermaid.append("    end")
        
        mermaid.append("end")
        mermaid.append("```")
        
        return "\n".join(mermaid)

    def generate_terraform_visual_diagram(self):
        """Generate infrastructure diagram using terraform-visual."""
        try:
            env_dir = os.path.join(self.project_root, "environments/dev")
            diagram_dir = os.path.join(self.project_root, "docs/diagrams")
            os.makedirs(diagram_dir, exist_ok=True)
            
            subprocess.run(
                ['terraform-visual', '--dir', env_dir, '--output', os.path.join(diagram_dir, 'infrastructure.png')],
                check=True
            )
            return True
        except Exception as e:
            print(f"Warning: Could not generate terraform-visual diagram: {e}")
            return False

    def update_readme(self):
        """Update the README.md with infrastructure diagrams and documentation."""
        self.analyze_terraform_modules()
        self.analyze_kubernetes_resources()
        
        readme_path = os.path.join(self.project_root, "README.md")
        
        # Read existing README content
        try:
            with open(readme_path, 'r') as f:
                content = f.read()
        except FileNotFoundError:
            content = "# GKE Cluster with Terraform\n\n"
        
        # Keep content before auto-generated section
        if "<!-- BEGIN AUTO-GENERATED -->" in content:
            content = content.split("<!-- BEGIN AUTO-GENERATED -->")[0]
        
        new_content = content.rstrip() + "\n\n"
        new_content += "<!-- BEGIN AUTO-GENERATED -->\n"
        new_content += "> ⚠️ This section is automatically generated. Do not modify manually.\n"
        new_content += f"> Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        
        # Add infrastructure diagrams section
        new_content += "## 📊 Infrastructure Diagrams\n\n"
        
        # Add Mermaid diagram
        new_content += "### Infrastructure Overview\n"
        new_content += self.generate_mermaid_diagram() + "\n\n"
        
        # Add terraform-visual diagram if generated
        if self.generate_terraform_visual_diagram():
            new_content += "### Detailed Infrastructure View\n"
            new_content += "![Infrastructure Diagram](docs/diagrams/infrastructure.png)\n\n"
        
        # Add module documentation
        new_content += "## 🏗 Terraform Modules\n\n"
        for module, details in self.terraform_modules.items():
            new_content += f"### {module}\n\n"
            
            if details['resources']:
                new_content += "**Resources:**\n"
                for resource in details['resources']:
                    new_content += f"- `{resource}`\n"
                new_content += "\n"
            
            if details['variables']:
                new_content += "**Variables:**\n"
                for var in details['variables']:
                    new_content += f"- `{var}`\n"
                new_content += "\n"
            
            if details['outputs']:
                new_content += "**Outputs:**\n"
                for output in details['outputs']:
                    new_content += f"- `{output}`\n"
                new_content += "\n"
        
        # Add Kubernetes documentation
        if self.kubernetes_resources:
            new_content += "## 🚢 Kubernetes Resources\n\n"
            for file, resources in self.kubernetes_resources.items():
                new_content += f"### {file}\n\n"
                for resource in resources:
                    new_content += f"- `{resource['kind']}/{resource['name']}`\n"
                new_content += "\n"
        
        # Write updated README
        with open(readme_path, 'w') as f:
            f.write(new_content)
        
        print("✅ README.md updated with infrastructure diagrams and documentation")

if __name__ == "__main__":
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    generator = InfrastructureDiagramGenerator(project_root)
    generator.update_readme()
