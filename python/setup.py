import setuptools

with open('requirements.txt') as f:
    requirements = f.read().splitlines()

setuptools.setup(
    name="eZeeKonfigurator",
    version="0.1",
    author="Vlad Grigorescu",
    author_email="vlad@es.net",
    description="A front-end to manage Zeek configurations",
    packages=setuptools.find_packages(),
    include_package_data=True,
    install_requires=requirements,
    scripts=['brokerd.py'],
)