const https = require('https');
const TOKEN = process.env.GITHUB_TOKEN || '';

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    const options = {
      headers: {
        'User-Agent': 'NodeJS',
        'Authorization': `token ${TOKEN}`
      }
    };
    https.get(url, options, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function run() {
  console.log('Waiting for Run #26 (or newer) to appear on GitHub...');
  let runId = null;
  let runNumber = 0;
  
  // Wait up to 2 minutes for run to appear
  for (let i = 0; i < 12; i++) {
    try {
      const list = await fetchJson('https://api.github.com/repos/Charan89781/LocalSync/actions/runs?per_page=5');
      const r = list.workflow_runs.find(run => run.head_branch === 'main');
      if (r && r.run_number > 25) {
        runId = r.id;
        runNumber = r.run_number;
        console.log(`\nDetected Run #${runNumber} (ID: ${runId})`);
        break;
      }
    } catch (e) {
      console.log('Error checking runs:', e.message);
    }
    await sleep(10000);
  }

  if (!runId) {
    console.log('Workflow run #26 did not start in time.');
    return;
  }

  // Poll the run status every 25 seconds
  let completed = false;
  const startTime = Date.now();
  const maxDuration = 20 * 60 * 1000; // 20 minutes max tracking

  while (!completed && (Date.now() - startTime) < maxDuration) {
    try {
      const r = await fetchJson(`https://api.github.com/repos/Charan89781/LocalSync/actions/runs/${runId}`);
      console.log(`\n[${new Date().toLocaleTimeString()}] Run #${runNumber} - Status: ${r.status} - Conclusion: ${r.conclusion || 'pending'}`);
      
      const jobs = await fetchJson(`https://api.github.com/repos/Charan89781/LocalSync/actions/runs/${runId}/jobs`);
      for (const job of jobs.jobs) {
        if (job.name === 'appium-tests') {
          console.log(`Job: ${job.name} - Status: ${job.status} - Conclusion: ${job.conclusion || 'running'}`);
          job.steps.forEach(step => {
            if (step.status !== 'queued') {
              console.log(`  - ${step.name}: ${step.status} (${step.conclusion || 'in progress'})`);
            }
          });
        }
      }

      if (r.status === 'completed') {
        completed = true;
        console.log(`\nRun completed! Conclusion: ${r.conclusion}`);
        break;
      }
    } catch (e) {
      console.log('Error fetching status:', e.message);
    }
    await sleep(25000);
  }
}

run();
