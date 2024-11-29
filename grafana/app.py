import subprocess

# List of scripts to run in order
scripts = [
    "01-datasource-adder.py",
    "02-folder-creator.py",
    "03-dashboard-validator.py",
    "04-dashboard-importer.py",
    "05-user-creator.py",
]

# Function to run scripts sequentially
def run_scripts(scripts):
    for script in scripts:
        print(f"Running {script}...")
        try:
            # Run the script and wait for it to complete
            result = subprocess.run(["python3", script], check=True)
            print(f"{script} completed with return code {result.returncode}.")
        except subprocess.CalledProcessError as e:
            print(f"Error occurred while running {script}: {e}")
            break  # Exit on error

if __name__ == "__main__":
    run_scripts(scripts)
