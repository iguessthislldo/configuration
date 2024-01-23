#!/usr/bin/env bash

cd "%dest%/OpenDDS"

cmake -B build \
  -G Ninja \
  "-DOPENDDS_ACE=%ace%" \
  -DCMAKE_UNITY_BUILD=TRUE \
  -DBUILD_SHARED_LIBS=TRUE \
  -DCMAKE_BUILD_TYPE=Debug \
  -DOPENDDS_SECURITY=TRUE \
  -DOPENDDS_BUILD_TESTS=TRUE
