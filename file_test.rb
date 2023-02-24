filename = 'testfile'

file1 = File.open(filename, 'w+')
file2 = File.open(filename, 'w+')

file1.seek(0, IO::SEEK_END)
file1.puts('File 1')
file1.flush

file2.seek(0, IO::SEEK_END)
file2.puts('File 2')
file2.flush
