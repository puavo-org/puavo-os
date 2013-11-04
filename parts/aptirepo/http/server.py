import tempfile
import shutil
import os.path

from flask import Flask, render_template, request

import aptirepo

app = Flask(__name__)

@app.route('/')
def index():
    return render_template("upload.html")

@app.route('/', methods=["POST"])
def upload():
    tmp_dirpath = tempfile.mkdtemp(".tmp", "aptirepo-upload-")

    if request.form["branch"] == "":
        return "branch missing", 400

    if request.files["changes"].filename == "":
        return ".changes file missing", 400

    changes_filepath = os.path.join(
        tmp_dirpath,
        request.files["changes"].filename
    )

    request.files["changes"].save(changes_filepath)

    for file in request.files.getlist("file"):
        file.save(
            os.path.join(tmp_dirpath, file.filename)
        )

    
    # TODO: read from config
    rootdir = ""
    confdir = ""
    
    repodir = os.path.join(rootdir, request.form["branch"])
    
    repo = aptirepo.Aptirepo(repodir, confdir)
    repo.import_changes(changes_filepath)
    repo.update_dists()

    shutil.rmtree(tmp_dirpath)
    return "ok"

# production: gunicorn server:app --bind 0.0.0.0:8080
if __name__ == '__main__':
    app.debug = True
    app.run(host="0.0.0.0", port=8080)
