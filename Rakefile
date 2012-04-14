require 'rake/clean'

VERSION_FILES = %w(
    src/injected.coffee
    Safari/BetterTender.safariextension/Info.plist
    Chrome/BetterTender/manifest.json
    update/BetterTender-Chrome-update.xml
    update/BetterTender-Safari-update.plist
 )

def coffee dst, src
    sh 'coffee', '-c', '-b', '-o', File.dirname(dst), src
end

def concat dst, *srcs
    puts 'cat >' +dst
    text = srcs.map { |src| File.read(src).rstrip + "\n" }
    File.open(dst, 'w') { |f| f.write text }
end

def version
    File.read('VERSION').strip
end

def subst_version_refs_in_file file, ver
    puts file
    orig = File.read(file)
    prev_line = ""
    anything_matched = false
    data = orig.lines.map do |line|
        if line =~ /\d\.\d\.\d/ && (line =~ /version/i || prev_line =~ /CFBundleShortVersionString|CFBundleVersion/)
            anything_matched = true
            new_line = line.gsub /\d\.\d\.\d/, ver
            puts "    #{new_line.strip}"
        else
            new_line = line
        end
        prev_line = line
        new_line
    end.join('')

    raise "Error: no substitutions made in #{file}" unless anything_matched

    File.open(file, 'w') { |f| f.write data }
end


file 'Safari/BetterTender.safariextension/global.js' => ['src/global.coffee'] do |task|
    coffee task.name, task.prerequisites.first
end

file 'Safari/BetterTender.safariextension/global-safari.js' => ['src/global-safari.coffee'] do |task|
    coffee task.name, task.prerequisites.first
end

file 'interim/injected.js' => ['src/injected.coffee'] do |task|
    coffee task.name, task.prerequisites.first
end

file 'interim/injected-safari.js' => ['src/injected-safari.coffee'] do |task|
    coffee task.name, task.prerequisites.first
end

file 'interim/injected-chrome.js' => ['src/injected-chrome.coffee'] do |task|
    coffee task.name, task.prerequisites.first
end

file 'Safari/BetterTender.safariextension/injected.js' => ['interim/injected.js', 'interim/injected-safari.js'] do |task|
    concat task.name, *task.prerequisites
end

file 'Chrome/BetterTender/global.js' => ['src/global.coffee'] do |task|
    coffee task.name, task.prerequisites.first
end

file 'Chrome/BetterTender/global-chrome.js' => ['src/global-chrome.coffee'] do |task|
    coffee task.name, task.prerequisites.first
end

file 'Chrome/BetterTender/injected.js' => ['interim/injected.js', 'interim/injected-chrome.js'] do |task|
    concat task.name, *task.prerequisites
end

desc "Pack Chrome extension"
task :chrome => :build do |task|
    full_ext = File.expand_path('Chrome/BetterTender')
    full_pem = File.expand_path('Chrome/BetterTender.pem')
    sh '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        "--pack-extension=#{full_ext}", "--pack-extension-key=#{full_pem}"
    mkdir_p "dist/#{version}"
    mv "Chrome/BetterTender.crx", "dist/#{version}/BetterTender.crx"
    sh 'open', '-R', File.expand_path("dist/#{version}/BetterTender.crx")
end

task :all => [:chrome]


desc "Embed version number where it belongs"
task :version do
    ver = version
    VERSION_FILES.each { |file| subst_version_refs_in_file(file, ver) }
    Rake::Task[:build].invoke
end

desc "Increase version number"
task :bump do
    prev = version
    components = File.read('VERSION').strip.split('.')
    components[-1] = (components[-1].to_i + 1).to_s
    File.open('VERSION', 'w') { |f| f.write "#{components.join('.')}\n" }
    puts "#{prev} => #{version}"
    Rake::Task[:version].invoke
end

desc "Build all files"
task :build => [
    'Safari/BetterTender.safariextension/global.js',
    'Safari/BetterTender.safariextension/global-safari.js',
    'Safari/BetterTender.safariextension/injected.js',
    'Chrome/BetterTender/global.js',
    'Chrome/BetterTender/global-chrome.js',
    'Chrome/BetterTender/injected.js',
]

def upload_file file, folder='dist'
    path = "#{folder}/#{file}"
    # application/x-chrome-extension
    sh 's3cmd', '-P', '--mime-type=application/octet-stream', 'put', path, "s3://files.tarantsov.com/BetterTender/#{file}"
    puts "http://files.tarantsov.com/BetterTender/#{file}"
end

desc "Upload the chosen build to S3"
task 'upload:custom' do |t, args|
    require 'rubygems'
    require 'highline'
    HighLine.new.choose do |menu|
        menu.prompt = "Please choose a file to upload: "
        menu.choices(*Dir['dist/**/*.{crx,safariextz,xpi}'].sort.map { |f| f[5..-1] }) do |file|
            upload_file file
        end
    end
end

desc "Upload the latest Chrome build to S3"
task 'upload:chrome' do
    upload_file "#{version}/BetterTender.crx"
end

desc "Upload the latest Safari build to S3"
task 'upload:safari' do
    upload_file "#{version}/BetterTender-#{version}.safariextz"
end

desc "Upload the latest builds of all extensions to S3"
task 'upload:all' => ['upload:chrome', 'upload:safari']

desc "Upload update manifests"
task 'manifest:upload' do
    upload_file "BetterTender-Chrome-update.xml",   'update'
    upload_file "BetterTender-Safari-update.plist", 'update'
end

desc "Tag the current version"
task :tag do
    sh 'git', 'tag', "v#{version}"
end
desc "Move (git tag -f) the tag for the current version"
task :retag do
    sh 'git', 'tag', '-f', "v#{version}"
end

task :default => :build

CLEAN.push *[
    'interim/injected.js',
    'interim/injected-safari.js',
    'interim/injected-chrome.js',
]
CLOBBER.push *[
    'Safari/BetterTender.safariextension/global.js',
    'Safari/BetterTender.safariextension/global-safari.js',
    'Safari/BetterTender.safariextension/injected.js',
    'Chrome/BetterTender/global.js',
    'Chrome/BetterTender/global-chrome.js',
    'Chrome/BetterTender/injected.js',
]
