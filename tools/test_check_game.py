"""The performance gate must reject a successful-but-slow Godot run."""
import json
import unittest
from check_game import assess_performance


class PerformanceGateTests(unittest.TestCase):
    def sample(self, **overrides):
        data=dict(scene="opening",passed=True,full_quality=True,frames=300,
                  sample_seconds=5.0,fps_mean=60.0,p95_ms=16.8)
        data.update(overrides)
        return "PERF_SUMMARY "+json.dumps(data)

    def test_old_marker_does_not_pass(self):
        output="\n".join(f"PERF fps={fps} draws=745 objects=19765 nodes=11458" for fps in (17,29,29,29,27))
        self.assertFalse(assess_performance(output,"perftest")[0])

    def test_runner_rechecks_budget(self):
        for data in (dict(fps_mean=29),dict(p95_ms=34),dict(full_quality=False),
                     dict(sample_seconds=0.5),dict(frames=0),dict(passed=False)):
            self.assertFalse(assess_performance(self.sample(**data),"perftest")[0])
        self.assertTrue(assess_performance(self.sample(),"perftest")[0])

    def test_missing_duplicate_or_malformed_results_fail(self):
        for output in (self.sample(),"PERF_SUMMARY {","PERF_SUMMARY []"):
            self.assertFalse(assess_performance(output,"perfscenes")[0])
        self.assertFalse(assess_performance(self.sample()+"\n"+self.sample(),"perftest")[0])


if __name__=="__main__":
    unittest.main()
