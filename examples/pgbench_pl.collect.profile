\set nbranches :scale
\set ntellers 10 * :scale
\set naccounts 100000 * :scale
\setrandom aid 1 :naccounts
\setrandom bid 1 :nbranches
\setrandom tid 1 :ntellers
\setrandom delta -5000 5000
SELECT pl_profiler_enable(true);
SELECT tpcb(:aid, :bid, :tid, :delta);
SELECT pl_profiler_collect_data();
SELECT pl_profiler_enable(false);
