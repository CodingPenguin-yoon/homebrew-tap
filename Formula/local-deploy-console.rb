class LocalDeployConsole < Formula
  desc "Local web console for deploying Kubernetes container images from Helm charts"
  homepage "https://github.com/CodingPenguin-yoon/local-deploy-console"
  url "https://github.com/CodingPenguin-yoon/local-deploy-console.git",
      tag:      "v0.1.1",
      revision: "c489079e65cc087bd89ea842f0bdd038018b6e6d"
  license "MIT"

  depends_on "git"
  depends_on "helm"
  depends_on "kubernetes-cli"
  depends_on "python@3.14"

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def install
    libexec.install "app.py", "charts.py", "static"
    resource("pyyaml").stage do
      libexec.install "lib/yaml"
      (pkgshare/"licenses/pyyaml").install "LICENSE"
    end
    (bin/"local-deploy-console").write <<~SH
      #!/bin/sh
      export LOCAL_DEPLOY_CONSOLE_STATE_DIR="${LOCAL_DEPLOY_CONSOLE_STATE_DIR:-$HOME/.local/share/local-deploy-console}"
      exec "#{Formula["python@3.14"].opt_bin}/python3.14" "#{libexec}/app.py" "$@"
    SH
  end

  test do
    port = free_port
    ENV["PORT"] = port.to_s
    pid = spawn bin/"local-deploy-console"
    begin
      body = shell_output("curl -fsS --retry 5 --retry-connrefused --retry-delay 1 http://127.0.0.1:#{port}/api/state")
      assert_equal [], JSON.parse(body).fetch("targets")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
