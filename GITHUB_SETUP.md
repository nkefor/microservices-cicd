# Push Project to GitHub

## Quick Setup (5 Minutes)

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. **Repository name**: `microservices-cicd` (or your preferred name)
3. **Description**: "Production-ready microservices CI/CD pipeline with Terraform, Ansible, Docker, Jenkins, and GitHub Actions"
4. **Visibility**: Public (for portfolio) or Private
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

### Step 2: Initialize Git and Push

Open Git Bash or terminal in the project directory and run:

```bash
cd /c/Users/keff2/microservices-cicd

# Initialize git (if not already done)
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Complete microservices CI/CD infrastructure

- Multi-server AWS infrastructure with Terraform
- Ansible provisioning and configuration
- 4 microservices (Node.js + Python)
- Docker containerization
- Jenkins pipeline
- GitHub Actions workflow
- Complete documentation"

# Add your GitHub repository as remote
# Replace YOUR_USERNAME with your actual GitHub username
git remote add origin https://github.com/YOUR_USERNAME/microservices-cicd.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 3: Verify

Go to your GitHub repository URL:
```
https://github.com/YOUR_USERNAME/microservices-cicd
```

You should see all your files!

---

## Detailed Instructions

### If You Need to Configure Git First

```bash
# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

### Using SSH Instead of HTTPS (Recommended)

If you prefer SSH authentication:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Copy the public key
cat ~/.ssh/id_ed25519.pub

# Add the key to GitHub:
# 1. Go to GitHub → Settings → SSH and GPG keys → New SSH key
# 2. Paste your public key

# Use SSH remote URL
git remote remove origin
git remote add origin git@github.com:YOUR_USERNAME/microservices-cicd.git
git push -u origin main
```

### If You Already Have a Git Repository

```bash
# Check current remotes
git remote -v

# If origin exists but points to wrong URL, update it
git remote set-url origin https://github.com/YOUR_USERNAME/microservices-cicd.git

# Push
git push -u origin main
```

---

## What Gets Pushed

Your repository will include:

```
✅ All microservices source code
✅ Terraform infrastructure code
✅ Ansible playbooks and roles
✅ Docker configurations
✅ CI/CD pipeline definitions
✅ Deployment scripts
✅ Complete documentation
✅ .gitignore (excludes sensitive data)
```

### Files Excluded (via .gitignore)

```
❌ node_modules/
❌ .env (secrets)
❌ *.tfstate (Terraform state)
❌ SSH keys
❌ AWS credentials
```

---

## After Pushing - Set Up GitHub Actions

### 1. Configure Repository Secrets

Go to your repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

| Secret Name | Value | How to Get |
|------------|-------|------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS IAM Console |
| `AWS_ACCOUNT_ID` | Your 12-digit AWS account | `aws sts get-caller-identity` |
| `SSH_PRIVATE_KEY` | Your SSH private key | `cat ~/.ssh/microservices-cicd` |
| `JWT_SECRET` | Random secret string | `openssl rand -base64 32` |

### 2. Enable GitHub Actions

1. Go to repository → Actions tab
2. Enable workflows if prompted
3. GitHub Actions will now run on push/PR

### 3. Test the Workflow

```bash
# Make a small change
echo "# Test update" >> README.md

# Commit and push
git add README.md
git commit -m "Test GitHub Actions workflow"
git push

# Check Actions tab to see the workflow run
```

---

## Update README with Your GitHub URL

Update the README.md to replace placeholder URLs:

```bash
# Open README.md and replace:
# <repository-url> → https://github.com/YOUR_USERNAME/microservices-cicd
```

---

## Create a Great Repository Description

On GitHub, go to your repository and click "About" (⚙️) to add:

**Description**:
```
Production-ready microservices CI/CD infrastructure with automated deployment
```

**Website**: (optional - add your deployed app URL)

**Topics** (add these tags):
```
microservices
devops
cicd
terraform
ansible
docker
aws
jenkins
github-actions
nodejs
python
infrastructure-as-code
```

---

## Optional: Create GitHub Releases

### Tag Your First Release

```bash
# Create a tag
git tag -a v1.0.0 -m "Initial release: Complete microservices CI/CD infrastructure"

# Push the tag
git push origin v1.0.0
```

### Create Release on GitHub

1. Go to repository → Releases → Create a new release
2. Choose tag: v1.0.0
3. Release title: "v1.0.0 - Initial Release"
4. Description:
   ```markdown
   ## 🎉 Initial Release

   Complete microservices CI/CD infrastructure with:
   - ✅ Terraform infrastructure automation
   - ✅ Ansible server provisioning
   - ✅ 4 containerized microservices
   - ✅ Jenkins + GitHub Actions CI/CD
   - ✅ AWS deployment scripts
   - ✅ Comprehensive documentation

   See [QUICKSTART.md](QUICKSTART.md) to get started!
   ```

---

## Update Your Portfolio/LinkedIn

After pushing, you can share:

**GitHub URL**:
```
https://github.com/YOUR_USERNAME/microservices-cicd
```

**LinkedIn Post Template**:
```
🚀 Excited to share my latest DevOps project!

Built a production-ready microservices CI/CD pipeline featuring:
✅ Infrastructure as Code (Terraform)
✅ Configuration Management (Ansible)
✅ Containerization (Docker)
✅ 4 microservices (Node.js + Python)
✅ Automated CI/CD (Jenkins + GitHub Actions)
✅ AWS deployment with monitoring

Tech stack: Terraform, Ansible, Docker, Node.js, Python, AWS, Jenkins, GitHub Actions

Full automation from infrastructure to deployment with comprehensive documentation.

🔗 https://github.com/YOUR_USERNAME/microservices-cicd

#DevOps #CloudComputing #AWS #CI/CD #Microservices #Terraform #Docker
```

---

## Troubleshooting

### Issue: Permission denied (publickey)

**Solution**: Set up SSH key or use HTTPS with token
```bash
# Use HTTPS with token
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/microservices-cicd.git
```

### Issue: Repository not found

**Solution**: Check repository URL and your GitHub username
```bash
# Verify remote
git remote -v

# Update if needed
git remote set-url origin https://github.com/YOUR_USERNAME/microservices-cicd.git
```

### Issue: Large files rejected

**Solution**: Check .gitignore is working
```bash
# Check what will be committed
git status

# If node_modules or large files appear, ensure .gitignore is correct
cat .gitignore
```

### Issue: Already initialized with different remote

**Solution**: Remove and re-add remote
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/microservices-cicd.git
git push -u origin main
```

---

## Next Steps After Pushing

1. ✅ Add repository description and topics
2. ✅ Configure GitHub Actions secrets
3. ✅ Add GitHub URL to your resume/portfolio
4. ✅ Create a release tag
5. ✅ Share on LinkedIn/social media
6. ✅ Add to your portfolio website

---

## Quick Reference Commands

```bash
# Check status
git status

# Add specific files
git add filename

# Add all changes
git add .

# Commit with message
git commit -m "Your message"

# Push to GitHub
git push

# Pull latest changes
git pull

# View commit history
git log --oneline

# Create new branch
git checkout -b feature-name

# Switch branches
git checkout main
```

---

**Ready to push?** Follow Step 1 and Step 2 above! 🚀
