desc "Restarts passenger"
task :restart do
  system("touch tmp/restart.txt")
end