function cb {
    python -c 'import sys;sys.stdout.write(sys.stdin.read().strip())' | pbcopy
}
