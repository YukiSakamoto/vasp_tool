#!/usr/bin/ruby

require "optparse"

DefaultSpinpolarization = false

filename = "EIGENVAL"


def calc_distance(pos1, pos2)
	if pos1.length == 3 and pos2.length == 3
		x2 = 0.to_f
		pos1.zip(pos2) {|dx| x2 += (dx[0] - dx[1])**2}
		norm = Math.sqrt(x2)
		return norm
	else
		raise
	end
end

def read_eigenval_file(num_in_each_path, spin_pol, outfilename)
	high_symmetry = []
begin
	outfile = File.open(outfilename, "w")
	File.open("EIGENVAL") do |file|
		num_bands = 0
		num_in_each_path =16
		num_k = 0
		current_x = 0.to_f	# for Band structure plotting

		prev_is_brank = true
		prev_pos = [0.to_f, 0.to_f, 0.to_f]
		file.each_line.with_index do |line, index|
			case index
			when 0,1,2,3,4 then
				;
			when 5 then
				num_bands = line.split[2].to_i
			else
				if line.strip.length == 0
					prev_is_brank = true
				else
					if prev_is_brank == true
						# Read new K-point
						current_pos =  line.split[0..2].map{|x| Float(x) }
						num_k += 1
						if num_k % num_in_each_path == 1	# High symmetry k point
							high_symmetry << current_x
						else
							current_x += calc_distance(current_pos, prev_pos)
						end
						prev_pos = current_pos
					else
						# Eigen values
						eigen = line.split
						if spin_pol == true 
							outfile.write( "#{current_x}  #{eigen[1]}  #{eigen[2]}\n")
						else
							outfile.write("#{current_x}  #{eigen[1]}\n")
						end
					end
					prev_is_brank = false
				end
			end
		end
		high_symmetry << current_x
	end
	outfile.close()
end
	return high_symmetry
end



def generate_plotscript(magnetic, high_symmetry)
	File.open("plot.in", "w") do |file|
		file.write("efermi = 0.0\n\n")
		file.write("ymin = -10\n")
		file.write("ymax =  10\n")
		file.write("set yrange [ymin:ymax]\n\n")

		file.write("set yzeroaxis\n")
		file.write("set grid ytics mytics\n\n")
		high_symmetry.each_with_index do |pt,i|
			file.write("pt#{i+1} = #{pt} \n")
		end
		# axis on the high symmetry points
		high_symmetry.each_with_index do |pt,i|
			file.write("set arrow #{i+1} nohead from pt#{i+1},ymin to pt#{i+1},ymax lc 'black'\n")
		end
		file.write("\n")

		file.write("set xtics (\\")
		file.write("\n")
		high_symmetry.each_with_index do |pt,i|
			file.write("'A' pt#{i+1}, \\")
			file.write("\n")
		end
		file.write(")\n")
		
		
		file.write('plot \\')
		file.write("\n")
		file.write('"band.dat" using ($1):($2-efermi) pt 7 ps 0.5,\\')
		file.write("\n")
		if magnetic == true
			file.write('"band.dat" using ($1):($3-efermi) pt 7 ps 0.5')
		end
	end
end

#============================================================
#  Main Routine
#============================================================
spin_pol = DefaultSpinpolarization
generate_plotscript = false
spin_pol = false
num_in_each_path = 0

opt = OptionParser.new
opt.on('-n num_of_intersections', 'number of intersections of each k-line') {|n| num_in_each_path = n}
opt.on('-s', '--spin', 'Spin polarization') {spin_pol = true}
opt.on('-p', 'generate plot script for gnuplot') {generate_plotscript = true}
opt.parse!(ARGV)

#Error Check
if num_in_each_path == 0
	raise "The number of k-points in each line is not specified"
end

high_symmetry = read_eigenval_file(num_in_each_path, false, "band.dat")
STDERR.write("band.dat is generated #{spin_pol == true ? "with" : "without"} spin polarization\n")

print "High symmetry coordinate\n"
high_symmetry.each do |x|
	print "#{x}\n"
end

if generate_plotscript == true
	generate_plotscript(spin_pol, high_symmetry)
end
