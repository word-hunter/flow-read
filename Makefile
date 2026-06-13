.PHONY: run ai-debug ai-debug-viewer ai-debug-trace-dir ai-debug-trace-file bench bench-open bench-all bench-lock bench-reset bench-trend package-local

run:
	@fvm dart run tool/run_app.dart $(ARGS)

ai-debug:
	@fvm dart run tool/run_app.dart --dart-define=FLOW_AI_DEBUG_TRACE=true $(ARGS)

ai-debug-viewer:
	@fvm dart run tool/ai_debug_viewer.dart $(ARGS)

ai-debug-trace-dir:
	@fvm dart run tool/ai_debug_viewer.dart --open-dir

ai-debug-trace-file:
	@fvm dart run tool/ai_debug_viewer.dart --open-latest

bench:
	@dart run tool/benchmark.dart run

bench-open:
	@dart run tool/benchmark.dart open

bench-all: bench bench-open

bench-lock:
	@dart run tool/benchmark.dart baseline-lock

bench-reset:
	@dart run tool/benchmark.dart baseline-reset

bench-trend:
	@dart run tool/benchmark.dart trend --last 10

bench-parse:
	@flutter test test/benchmark/epub_parse_benchmark_test.dart --tags benchmark --concurrency=1

bench-profile:
	@dart run --observe tool/parse_profile.dart

bench-analysis:
	@flutter test test/benchmark/chapter_analysis_benchmark_test.dart --tags benchmark --concurrency=1

bench-difficulty:
	@flutter test test/benchmark/difficulty_calc_benchmark_test.dart --tags benchmark --concurrency=1

bench-search:
	@flutter test test/benchmark/full_text_search_benchmark_test.dart --tags benchmark --concurrency=1

bench-trend-%:
	@dart run tool/benchmark.dart trend --bench $* --last 10

package-local:
	@fvm dart run tool/release.dart package-local --skip-tests $(ARGS)
