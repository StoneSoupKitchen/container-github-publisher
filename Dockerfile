#/////////////////////////////////////////////////////////////////////////////#
#
# Copyright (c) 2022, Joshua Ford
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#/////////////////////////////////////////////////////////////////////////////#

FROM alpine:3.17.2 as builder

RUN apk add --update --no-cache go rust cargo
RUN set -x \
  && cargo install git-cliff \
  && go install github.com/tcnksm/ghr@latest

#//////////////////////////////////////////////////////////////////////////////

FROM alpine:3.17.2

RUN set -x \
  && apk add --no-cache bash ca-certificates curl git make python3 py3-pip \
  && pip3 install --no-cache-dir git-semver \
  && mkdir -p /opt/ssk/git-cliff

COPY --from=builder /root/.cargo/bin/git-cliff /usr/bin/git-cliff
COPY --from=builder /root/go/bin/ghr /usr/bin/ghr
COPY assets/bin/create_release /usr/bin/create_release
COPY assets/git-cliff /opt/ssk/git-cliff

USER 1001
CMD [ "/bin/bash" ]

