import base64
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from server import InputError, render_video, validate_project

# Tiny syntactically valid PNG, generated in-memory by FFmpeg during integration test.
class StudioTests(unittest.TestCase):
    def good(self):
        return {'image_data_url':'data:image/png;base64,'+base64.b64encode(b'\x89PNG\r\n\x1a\n' + b'placeholder').decode(), 'scenes':[{'style':'reveal','seconds':2,'caption':'Test'}]}

    def test_accepts_valid_metadata(self):
        img,ext,shots=validate_project(self.good())
        self.assertEqual(ext,'png')
        self.assertEqual(shots[0]['caption'],'Test')

    def test_refuses_bad_type_and_costly_duration(self):
        p=self.good();p['scenes'][0]['style']='arbitrary'
        with self.assertRaises(InputError):validate_project(p)
        p=self.good();p['scenes']=[{'style':'hero','seconds':6,'caption':''} for _ in range(5)]
        with self.assertRaises(InputError):validate_project(p)

    def test_rejects_disguised_bad_image(self):
        p=self.good();p['image_data_url']='data:image/jpeg;base64,'+base64.b64encode(b'notajpeg').decode()
        with self.assertRaises(InputError):validate_project(p)

    @unittest.skipUnless(shutil.which('ffmpeg') and shutil.which('ffprobe'),'FFmpeg binaries required')
    def test_mp4_export_9_by_16(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory);image=path/'ref.png';video=path/'out.mp4'
            subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-f','lavfi','-i','color=c=white:s=240x400','-frames:v','1','-y',str(image)],check=True)
            p=self.good();p['image_data_url']='data:image/png;base64,'+base64.b64encode(image.read_bytes()).decode()
            p['scenes']=[{'style':'reveal','seconds':1,'caption':'Internal concept'}]
            render_video(p,video,width=360,height=640)
            data=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=width,height','-of','json',str(video)]))
            self.assertEqual((data['streams'][0]['width'],data['streams'][0]['height']),(360,640))
            self.assertGreater(video.stat().st_size,1000)

if __name__=='__main__':unittest.main()