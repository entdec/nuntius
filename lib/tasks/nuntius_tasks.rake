namespace :nuntius do
  namespace :tailwindcss do
    desc "Configure your Tailwind CSS"
    task :config do
      Rails::Generators.invoke("nuntius:tailwind_config", ["--force"])
    end
  end
end

if Rake::Task.task_defined?("tailwindcss:build")
  Rake::Task["tailwindcss:build"].enhance(["nuntius:tailwindcss:config"])
  Rake::Task["tailwindcss:watch"].enhance(["nuntius:tailwindcss:config"])
end
