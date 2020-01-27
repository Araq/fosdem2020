# fosdem2020
Slides and source code for my FOSDEM 2020 talk "Nim - Move semantics".

# Build

To build the slides run ``nim c -r build.nim``.

# Benchmarks

To compile the benchmarks use these commands:

```
nim c -d:danger --gc:markAndSweep bintrees_gcs.nim
nim c -d:danger --gc:boehm bintrees_gcs.nim
nim c -d:danger --gc:refc bintrees_gcs.nim
nim c -d:danger --gc:arc bintrees_gcs.nim
nim c -d:danger --gc:arc bintrees_manual.nim
nim c -d:danger --gc:arc bintrees_pools.nim
```
