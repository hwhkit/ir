#!/bin/sh
# 注入一个演示任务（SQL 直插租约队列；演示用法，生产走 API/团队入口）。
# 用法：./demo-task.sh [可选任务描述]
set -eu
DESC="${1:-demo task $(date +%H:%M:%S)}"
docker exec ir-db psql -U ir -d ir -c "
WITH new_task AS (
  INSERT INTO agent_pull_tasks (run_id, agent_slug, agent_revision, executor_kind,
    payload_json, state, execution_dead_ns, queue_expires_ns, created_ns, created_at)
  VALUES ('run_demo_' || floor(random()*1e8)::text, 'pool-demo',
    (SELECT revision FROM agents WHERE slug='pool-demo'), 'remote-pull',
    json_build_object('taskBrief', '$DESC', 'params', json_build_object('source','docker-demo'))::text,
    'queued', (extract(epoch from now())+600)*1000000000,
    (extract(epoch from now())+3600)*1000000000,
    (extract(epoch from now())*1000000000)::bigint,
    to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SSOF'))
  RETURNING run_id, agent_slug, agent_revision, executor_kind, created_ns)
INSERT INTO agent_runs (agent_slug, run_id, agent_revision, executor_kind, execution_mode,
  status, request_json, created_at)
SELECT n.agent_slug, n.run_id, n.agent_revision, n.executor_kind, 'remote_pull', 'running',
  json_build_object('source','docker-demo')::text, to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SSOF')
  FROM new_task n"
echo "task queued — watch: docker compose -f deploy/docker-compose.yml logs -f edge"
