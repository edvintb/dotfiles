#!/usr/bin/env python3

import subprocess
import re

def get_running_jobs():
    result = subprocess.run(['ray', 'job', 'list'], capture_output=True, text=True)
    
    running_jobs = []
    # Look for job_id='XXXXX' patterns in the output
    for line in result.stdout.split('\n'):
        if 'JobDetails' in line:
            # Extract job_id
            job_id_match = re.search(r"job_id='([^']*)'", line)
            if not job_id_match:
                continue
            job_id = job_id_match.group(1)
            if not job_id:  # Skip if job_id is None/empty
                continue
                
            # Extract entrypoint
            entrypoint_match = re.search(r"entrypoint='([^']*)'", line)
            entrypoint = entrypoint_match.group(1) if entrypoint_match else "Unknown"
            
            # Extract status
            status_match = re.search(r"status=<JobStatus\.([^:]*)", line)
            status = status_match.group(1) if status_match else "Unknown"
            
            if status == "RUNNING":
                running_jobs.append({
                    'id': job_id,
                    'entrypoint': entrypoint
                })
    
    return running_jobs

def kill_job(job_id):
    subprocess.run(['ray', 'job', 'stop', job_id])
    print(f"Killed job {job_id}")

def main():
    running_jobs = get_running_jobs()
    
    if not running_jobs:
        print("No running jobs found")
        return
        
    if len(running_jobs) == 1:
        job = running_jobs[0]
        print(f"Found one running job: {job['id']}")
        print(f"Entrypoint: {job['entrypoint']}")
        kill_job(job['id'])
    else:
        print("Multiple running jobs found:")
        for i, job in enumerate(running_jobs, 1):
            print(f"{i}. Job {job['id']}")
            print(f"   Entrypoint: {job['entrypoint']}")
            print()
            
        while True:
            choice = input("Enter number of job to kill (or 'q' to quit): ")
            if choice.lower() == 'q':
                return
            try:
                idx = int(choice) - 1
                if 0 <= idx < len(running_jobs):
                    kill_job(running_jobs[idx]['id'])
                    break
                else:
                    print("Invalid job number")
            except ValueError:
                print("Please enter a valid number")

if __name__ == '__main__':
    main()
