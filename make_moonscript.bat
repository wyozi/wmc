@echo off

moonc lua 2>&1 && (
    echo MoonScript compiled!
) || (
    echo No MoonScript compiler in PATH. Read README.md
)
