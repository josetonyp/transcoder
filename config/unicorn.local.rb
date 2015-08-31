worker_processes 4

working_directory "/Users/josetonyp/Workspace/traductor" # available in 0.94.0+
listen "127.0.0.1:3000", :tcp_nopush => true
timeout 60
pid "/Users/josetonyp/Workspace/traductor/tmp/pids/unicorn.pid"
stderr_path "/Users/josetonyp/Workspace/traductor/log/unicorn.stderr.log"
stdout_path "/Users/josetonyp/Workspace/traductor/log/unicorn.stdout.log"

# combine Ruby 2.0.0dev or REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

check_client_connection false

before_fork do |server, worker|

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
  #
  # Throttle the master from forking too quickly by sleeping.  Due
  # to the implementation of standard Unix signal handlers, this
  # helps (but does not completely) prevent identical, repeated signals
  # from being lost when the receiving process is busy.
  # sleep 1
end

after_fork do |server, worker|

end
