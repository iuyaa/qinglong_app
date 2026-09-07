"""Generate metadata only for the signed APK produced by this workflow."""
import hashlib
import json
import os
from pathlib import Path

apk = Path('artifacts/qinglong-android.apk')
version = os.environ['APP_VERSION']
code = int(os.environ['GITHUB_RUN_NUMBER'])
manifest = dict(versionName=version, versionCode=code, packageName='io.github.iuyaa.qinglong',
                size=apk.stat().st_size, sha256=hashlib.sha256(apk.read_bytes()).hexdigest(),
                url=f'https://github.com/iuyaa/qinglong_app/releases/download/v{version}%2B{code}/qinglong-android.apk')
Path('artifacts/update.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
