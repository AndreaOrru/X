from setuptools import setup

setup(name='xlang',
      version='0.0.1',
      description='High-level system programming language',
      url='http://github.com/AndreaOrru/X',
      author='Andrea Orru',
      author_email='andreaorru1991@gmail.com',
      license='BSD',
      packages=['xlang'],
      install_requires=[
          'antlr4-python3-runtime',
          'llvmlite',
      ],
      entry_points={
          'console_scripts': 'xlang = xlang.cli:main'
      })
