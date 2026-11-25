// Run with NODE_PATH pointing at a local Playwright installation.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {chromium} = require('playwright');
const root = path.resolve(__dirname, '..');
const assets = path.join(root, 'assets/web/three');
const models = fs.readdirSync(path.join(root, '.artifacts')).filter(x => x.endsWith('_lite.glb'));
const server = http.createServer((req, res) => {
  const relative = decodeURIComponent(new URL(req.url, 'http://localhost').pathname).slice(1);
  const file = relative.endsWith('_lite.glb') && models.includes(relative)
    ? path.join(root, '.artifacts', relative)
    : relative.startsWith('draco/') ? path.join(assets, path.basename(relative))
    : path.join(assets, path.basename(relative));
  if (!fs.existsSync(file)) { res.writeHead(404).end(); return; }
  res.setHeader('Content-Type', file.endsWith('.js') ? 'application/javascript' : file.endsWith('.glb') ? 'model/gltf-binary' : 'text/html');
  fs.createReadStream(file).pipe(res);
});
(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const browser = await chromium.launch({headless:true, executablePath:process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
  const results=[];
  try {
    for (const webgl1 of [false, true]) {
      for (const model of models) {
        const page = await browser.newPage({viewport:{width:640,height:320},deviceScaleFactor:1});
        await page.route('**/*', route => new URL(route.request().url()).hostname === '127.0.0.1' ? route.continue() : route.abort());
        await page.addInitScript(({webgl1}) => {
          window.viewerEvents=[];
          window.Dashcore3d={postMessage:message => window.viewerEvents.push(JSON.parse(message))};
          if (webgl1) {
            const original=HTMLCanvasElement.prototype.getContext;
            HTMLCanvasElement.prototype.getContext=function(type,...args) {return type==='webgl2' ? null : original.call(this,type,...args);};
          }
        },{webgl1});
        await page.goto(`http://127.0.0.1:${server.address().port}/viewer.html`);
        await page.evaluate(model => window.initDashcore({src:`/${model}`,lowResource:true,autoRotate:false,cameraControls:true,disableZoom:true,disablePan:true,azimuth:35,polar:78,distanceFactor:1.7,color:'#B5BACA'}),model);
        await page.waitForFunction(() => window.viewerEvents.some(e=>['ready','error','loadError'].includes(e.type)),null,{timeout:30000});
        const events=await page.evaluate(()=>window.viewerEvents);
        assert.equal(events.some(e=>e.type==='error'||e.type==='loadError'),false,JSON.stringify({model,events}));
        const ready=events.find(e=>e.type==='ready');
        assert.ok(ready,model);
        assert.equal(ready.data.low,true);
        if(webgl1) assert.equal(ready.data.webgl,1);
        await page.evaluate(()=>{ window.frameRequests=0; const original=window.requestAnimationFrame;
          window.requestAnimationFrame=(fn)=>{window.frameRequests++;return original.call(window,fn);}; });
        await page.waitForTimeout(100);
        assert.equal(await page.evaluate(()=>window.frameRequests),0,'Stationary 3D must not continuously render');
        await page.evaluate(()=>window.updateDashcoreCamera({azimuth:50,polar:75,distanceFactor:1.7}));
        if(model==='OPTIMA2012_lite.glb'&&!webgl1) await page.screenshot({path:path.join(root,'docs/screenshots/v2-vehicle-3d.png')});
        await page.evaluate(()=>window.disposeDashcore());
        results.push({model,webgl:ready.data.webgl,low:true,idleFrameRequests:0});
        await page.close();
      }
    }
    fs.writeFileSync(path.join(root,'.artifacts/viewer-verification.json'),JSON.stringify(results,null,2));
    console.log(`PASS: ${results.length} model loads, WebGL 1/2, camera changes, stationary render loop stopped`);
  } finally {await browser.close();server.close();}
})().catch(error=>{console.error(error);server.close();process.exitCode=1;});
