# AWS公式のFluent Bitイメージをベース
FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:stable

# カスタム設定ファイルをコピー
COPY fluent-bit-multi-firehose.conf /fluent-bit/etc/fluent-bit.conf

# 設定ファイルの権限を設定
USER root
RUN chmod 644 /fluent-bit/etc/fluent-bit.conf
USER 1000

# デフォルトの設定ファイルパスを上書き
ENV FLB_CONFIG_FILE=/fluent-bit/etc/fluent-bit.conf 