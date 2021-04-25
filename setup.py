import sys
from distutils.version import StrictVersion
from setuptools import setup, __version__

if StrictVersion(__version__) < StrictVersion('20.2'):
    print('your setuptools version does not support PEP 508. Upgrade setuptools and repeat the installation.')
    sys.exit(1)

with open('brokerd/requirements.txt') as f:
    requirements = []

    for line in f.readlines():
        line = line.strip()
        if line.startswith("git+"):
            egg = line.split('#egg=', 1)[1]
            requirements.append(f"{egg} @ {line}")
        else:
            requirements.append(line)

setup(
    name="ezeekonfigurator_client",
    version="0.1",
    author="Vlad Grigorescu",
    author_email="vlad@es.net",
    description="A front-end to manage Zeek configurations",
    packages=setuptools.find_packages(),
    include_package_data=True,
    install_requires=requirements,
    scripts=['brokerd/run_brokerd.py'],
    data_files=[('zeek_scripts', ['scripts/__load__.zeek', 'scripts/options.zeek'])]
)
