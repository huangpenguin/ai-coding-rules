# BasicSR 第一阶段微调

目标：先验证自己的数据能否训练出合理结果，不追 SOTA，不先改网络。

推荐流程：

```bash
git clone <your-basicsr-fork>
cd BasicSR
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
uv pip install -e .
init-ai
```

这里 `init-ai` 默认只注入 core rules，不会加入 Docker / CI。

第一阶段先改：

- 数据路径
- `options/train/*.yml`
- 预训练权重路径
- batch size / crop size / iter

先直接跑：

```bash
python basicsr/train.py -opt options/train/your_config.yml
```

效果不好时，优先检查数据配对、scale、噪声/clean GT、配置和预训练权重。不要一开始就改网络。

需要 Docker / GPU Runner 时再执行：

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```
