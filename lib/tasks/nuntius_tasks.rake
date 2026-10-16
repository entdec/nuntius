namespace :nuntius do
  namespace :tailwindcss do
    desc "Configure your Tailwind CSS"
    task :config do
      Rails::Generators.invoke("nuntius:tailwind_config", ["--force"])
    end
  end
end

# tailwindcss-rails v4 picks up app/assets/tailwind/nuntius/engine.css itself (via tailwindcss:engines),
# so only hook in the v3 config generator when that task is absent.
if Rake::Task.task_defined?("tailwindcss:build") && !Rake::Task.task_defined?("tailwindcss:engines")
  Rake::Task["tailwindcss:build"].enhance(["nuntius:tailwindcss:config"])
  Rake::Task["tailwindcss:watch"].enhance(["nuntius:tailwindcss:config"])
end
