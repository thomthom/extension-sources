path = 'test.tmp'

begin
  file1 = File.open(path, "a:UTF-8")
  file2 = File.open(path, "a:UTF-8")

  file1.puts "Hello File1 #1"; file1.flush
  file2.puts "Hello File2 #1"; file2.flush
  file1.puts "Hello File1 #2"; file1.flush
  file2.puts "Hello File2 #2"; file2.flush

ensure
  file1.close
  file2.close
end
