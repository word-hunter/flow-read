.PHONY: bench bench-open bench-all bench-lock bench-reset bench-trend

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
	@flutter test test/benchmark/epub_parse_benchmark_test.dart --tags benchmark

bench-profile:
	@dart run --observe tool/parse_profile.dart

bench-analysis:
	@flutter test test/benchmark/chapter_analysis_benchmark_test.dart --tags benchmark

bench-difficulty:
	@flutter test test/benchmark/difficulty_calc_benchmark_test.dart --tags benchmark

bench-search:
	@flutter test test/benchmark/full_text_search_benchmark_test.dart --tags benchmark

bench-trend-%:
	@dart run tool/benchmark.dart trend --bench $* --last 10
