import tempfile
import shutil
import os.path
import aptirepo
import sys
import logging

from debian import deb822
from flask import Flask, render_template, request


confdir = os.environ.get("APTIREPO_CONFDIR")
if not confdir:
    confdir = "/etc/aptirepo"

def read_config(config_filepath):
    config = None
    with open(config_filepath, "r") as config_file:
        content = config_file.read()
        config =  deb822.Deb822(content.split("\n"))
    return config

config = read_config(os.path.join(confdir, "http.conf"))

app = Flask(__name__)

@app.route('/')
def index():
    return render_template("upload.html")



@app.route('/', methods=["POST"])
def upload():

    if "branch" not in request.form or request.form["branch"] == "":
        return "branch missing", 400

    if "changes" not in request.files or request.files["changes"].filename == "":
        return ".changes file missing", 400

    repodir = os.path.join(
        config["Repository-Parent"],
        request.form["branch"]
    )

    if not os.path.isdir(repodir):
        os.makedirs(repodir)

    tmp_dirpath = tempfile.mkdtemp(".tmp", "aptirepo-upload-")


    changes_filepath = os.path.join(
        tmp_dirpath,
        request.files["changes"].filename
    )

    request.files["changes"].save(changes_filepath)

    for file in request.files.getlist("file"):
        file.save(
            os.path.join(tmp_dirpath, file.filename)
        )

    repo_kwargs = {}
    try:
        repo_timeout = config["Repository-Lock-Timeout"]
    except KeyError:
        pass
    else:
        repo_kwargs["timeout_secs"] = int(repo_timeout)

    repo = aptirepo.Aptirepo(repodir, confdir, **repo_kwargs)
    repo.import_changes(changes_filepath)
    repo.update_dists()
    repo.sign_releases()

    shutil.rmtree(tmp_dirpath)
    return "ok"

@app.route('/upload_deb', methods=["POST"])
def upload_deb():
    codename = ""

    if "codename" in request.form and request.form["codename"] != "":
        codename = request.form["codename"]

    repodir = os.path.join(
        config["Repository-Parent"],
        request.form["branch"]
    )

    if not os.path.isdir(repodir):
        os.makedirs(repodir)

    for deb_file in request.files.getlist("deb"):
        tmp_dirpath = tempfile.mkdtemp(".tmp", "aptirepo-upload-")
        deb_package_path = os.path.join(tmp_dirpath, deb_file.filename)
        deb_file.save(deb_package_path)

        repo_kwargs = {}
        try:
            repo_timeout = config["Repository-Lock-Timeout"]
        except KeyError:
            pass
        else:
            repo_kwargs["timeout_secs"] = int(repo_timeout)

        repo = aptirepo.Aptirepo(repodir, confdir, **repo_kwargs)
        repo.import_deb(deb_package_path, codename)
        repo.update_dists()
        repo.sign_releases()

        shutil.rmtree(tmp_dirpath)

    return "ok"

# production: gunicorn server:app --bind 0.0.0.0:8080
if __name__ == '__main__':
    app.debug = True
    app.run(host="0.0.0.0", port=8081)

if not app.debug:
    app.logger.addHandler(logging.StreamHandler(sys.stdout))

