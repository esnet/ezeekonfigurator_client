import setuptools

with open('brokerd/requirements.txt') as f:
    requirements = []

    for line in f.readlines():
        line.strip()
        if line.startswith("git+"):
            egg = line.split('#egg=', 1)[1]
            requirements.append(f"{egg} @ {line}")
        else:
            requirements.append(line)

print(requirements)

setuptools.setup(
    name="eZeeKonfigurator",
    version="0.1",
    author="Vlad Grigorescu",
    author_email="vlad@es.net",
    description="A front-end to manage Zeek configurations",
    packages=setuptools.find_packages(),
    include_package_data=True,
    install_requires=requirements,
    scripts=['brokerd/run_server.py'],
)