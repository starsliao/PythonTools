#!/bin/bash
if [ "$1" ]
then
  msg=$1
else
  msg="update"
fi
rm -rvf hwpy.egg-info dist hwpy/*.pyc
python setup.py sdist
twine upload dist/hwpy*.tar.gz && \
rm -rvf hwpy.egg-info dist && \
git add --all && \
git commit -m "$msg" && \
git push
