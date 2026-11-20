class LocalDeployConsole < Formula
  desc "Local web console for deploying Kubernetes container images from Helm charts"
  homepage "https://github.com/CodingPenguin-yoon/local-deploy-console"
  url "https://github.com/CodingPenguin-yoon/local-deploy-console.git",
      tag:      "v0.1.0",
      revision: "3441d04be4056d569981d9c876bc0fc4d7ced074"
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
      require "net/http"
      uri = URI("http://127.0.0.1:#{port}/api/state")
      response = retry_block { Net::HTTP.get_response(uri) }
      assert_equal "200", response.code
      assert_equal [], JSON.parse(response.body).fetch("targets")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
