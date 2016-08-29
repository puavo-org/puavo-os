class adm::users {
  include adm

  adm::user {
    'puavo-os':
      uid => 1000;

    'adm-vmlintu':
      sshkey      => 'AAAAB3NzaC1kc3MAAACBAKt2fmhYJOHT7dS/3GPv3MSp6NuCOpWpSdan5apzEc4BPz6ouxwneR/KudMvy4HsZn7MBiqLnAV/Dq1K8MBWtxU3VKviBskXyugcBBrjHiwfUYuGM5tqKR7VJ/GSV2S2fKdAN/F5QrWUmZfTlVFOVFvWd5fDfmMDPcXExEh+iZB1AAAAFQCQJJpJEH1nulob2MnNUk4S62hbBQAAAIBI/Unwn94+c5P0mhnQ1V65KVKNAy2zBMs9x4ykHHZiSR7yrRP4k4qjeSXZytaXxevzQk+sB2bHIsBYxXhixUedjxT72v429iZiaYGEj8lkDdHCVqBmMg7wfR7TTEopbvclcxOGHITWhSKN+2PHhRN2rKJFLp5ByaRpw4rRlWfeBQAAAIBiGncHnSwTiVHpWhw+7uYD3eJsGu8EBFubfQ7ldLuhnF3mTREXLbgryrS2dcSSlXws5qGQ+eXilSD09+CznlDL84zdFs5w2JhRXEl1vA6J+7Xj+EGtkk4c+gJ9rlWKYpHEUe8wqewRuXAIBVu8gYEoS74P2tOl9vWrBflT07jDfw==',
      sshkey_type => 'dsa',
      uid         => 1001;

    'adm-juhaerk':
      sshkey      => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAnlcriJylDCXUIy619nX/nBjDLaf4M668nz7HBFfwA2rlsbA48LPZ+gkUB2KgW6GUikT13djFo352HYQ2m3NJzNjTtk5hmZuGVb7eNmE5Q2/rr9D3vkEJN8qDDRsiKSk8nS3sya4pv7+BMe/4OoDV4ANvehd7svn3osqzHstQHvm+a6ycN8bqCsBYgj9is7PDnnoKA4XU6aOq13OfoB6XIZx3Q6qy745k976lOFOHVNtrUWJbUwz8OpDl3rU02Bc3P7a98BbuAwWp37AQSPg8Mhn8oXrUW/Dw5xeGVSVC1SFG4hEcEnF9gIYMY8WAYBzLOExPU/riOc/PnmX7vlJ/Zw==',
      sshkey_type => 'rsa',
      uid         => 1002;

    'adm-asokero':
      sshkey      => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAoEsLAeV9AfZV4WOVXHIYyDvzHheQ7tagGWO7KsIYjTDDvxqOMMXgqVibRkoY3itqX2lI9e3pheD/7wC/abOx8Zzb0Qs5tKfCNe2U6CxOsN0cCEvcEZc3/ItsR0ynO5elT+DDRU3mF6zBahpZEq1mpPDDbNK/JziFOY+YSvphxn5iYQEOcuJPkiy4+kfuLH7HD5B/9h/Fa7x6IKWKzZR3vgqyD/xftZShN2ZklyQmxziq9+/bfMa/v8Ny8wuf4MO7mpEUWg3bAV0akqOqxm6nFtk0Fy7gmZObElZkmpldEnA39ALt16fncp8qvcW2U0FCgz0gHu3m2HeLBV3CU7ekpQ==',
      sshkey_type => 'rsa',
      uid         => 1003;

    'adm-cjoohs':
      sshkey      => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAr8YO+0Ygwy592shekjeN6g+8f2TXY3Nt7eTV7u36eVQwLoy4+pThtVCKk1ei2u6cJi2AeKkIK/mWVkiju6OUTrMjsBIi3VBSUc+O8/cgi73SjuZjvRXuQUP27zFyoPLVbwk99K15upHJtV7FEIzfTretU6f5KssDjDyo/GJTSSL11R0HQWbGkSSAmEGqz1C965NJ4T78L3jLznf9bxkjClfpVaHXanEEvya3qay7izcBZT3k4R32hhTVzRhb2obt5BPguzkfz3jfG1/YfS8AjHTTJDz+uPdWVLpFdFB40TOkjgW6kQCq5c4VqAjeLYvo6lda9NP8HqHPm9pB39/MDQ==',
      sshkey_type => 'rsa',
      uid         => 1004;

    'adm-hannele':
      sshkey      => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAxnP1o+ujlUgNiqbdimpsHUydYdxiWILXo0KnhDPEVfytXnSrP9MEW5pfT2jt1Rkrg66HkdVjhaIZEqigPlxhliDEdnsSjwvewR5DIydUPjXqutdfUs/Af3CZYbQ0f19yCDnkPbuNFMOkmcH0xDdHVcTp6lAZhQdqiJ21JtBrIO8a1pqYw08bbZuIpMltGlXqMUTvII/jplvx6/hIptA01GbAml34V4W+IftNNAdKQwVKebbxHcEirhfPo5mDI7+MEyxiA8LwkGlTllJaR8KQx3nhL+jnyF+SFh/y1BCBb3vK2V2Wjklanpj648NN9FyFJYCR2LcmoR+1Hd+L0l51kQ==',
      sshkey_type => 'rsa',
      uid         => 1005;

    'adm-mjokinen':
      sshkey      => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAvs4IP+ijmRvoE1x1mfbzaHXEd11czXQhVir/VtrEC4S6T9isqRwe1l+sKsrnlNp4X8qfqR7mPUuw/UoUAD2Zuk0zTtijxFVneqEEM4Q5KCo2WJrHt1DhvGdI9oBIQOFLLLJdX5sAq1JkVelrfVRSUtDCkKVLTj5pE+R7duYPdVO3804oO5GV2oroYfgDALf+Zt1YgfQuLeEw5ubu0hmk8Vf1RYmQBCiQPAcny0R5JbEWygugQJ5PVFYoi8Q7uYQzM1TJBy2xkZvJI/Yl3LJ9VO0ddh7hLaszAyT0O9YbmBbez3cmrukbPOzclmglmrSs2DuTtdZCrWNfiGrMORR38w==',
      sshkey_type => 'rsa',
      uid         => 1006;

    'adm-jokor':
      sshkey      => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA3xr9LhWPstYx+FK2pndpaQZAAoT52uaTNrovayaNh41x593k4QQa4K1QIVTqlOaGNaq5NxFSQrYIMR53Jy2xRo88MD7o78KdqAl64kscD73DrA1Q1HpupS7ksMbnNkD5PB0mv2/+FBnWCXspGiEAHVSg3ARP3lBsWekgREox6r01C2ghPR6ZaGgB8K5cm9BEiXRmMvkWoPtxSLMGAdPS6mgzb6BoWUER6lf7sa/asDwNcAAwLLGf2ZICUpEzH+DaQrrV9wCxHcZvpk/pfnebjS7ld4x5NmXnmBWQt/qe6cDHRjYoyeeGEQFzWPaePN6ITf07/zBTLJHdY8UnyhtZDw==',
      sshkey_type => 'rsa',
      uid         => 1007;

    'adm-ptoivola':
      sshkey      => 'AAAAB3NzaC1yc2EAAAABIwAAAQEApIdhSUFOC5lbtyd+8duSn6Dt4wzLxz16Zfqwccsx3KXSDw5/tmhyRWAMcE5tTWOIiHW5Y5u7syJ9ZJS68FJLBx3o/I5SBIKiN32isyytqASsEU3mm+yS67yHU6/9bNGAN998YM9/Xk3CRJdgFn9nBGP9hRt+FCv6TBzB5NDOfW/tpkR76pPayiOUOAkrVAK3m0wrFi1/VwzdzTn/cRRBMUu/f/Gau7ZXaeBFP+WN5AM0OPWGvRFS3quTUelUVoWDrcWs2iwGpmTURUFqK48gWw4dWDv71ps/YB2cMsqbC3DDHecFa64ZgM+ui4mIwKaGO9+A8jaxOsjci9kQ7/9UTw==',
      sshkey_type => 'rsa',
      uid         => 1008;

    'adm-tuomasjjrasanen':
      sshkey      => 'AAAAB3NzaC1yc2EAAAABIwAAAgEAzb9iWl3tIOcY/RvfeFk+DHa11G4SY1vbc+E1og6WAU4pBUxBaBqcfuCjNWBCpOL3NiNj529c/zT4gdEbkVX8zlQH74zn4vC60C3FQFUe1nKSAO33n6aj1VFfhCJDzUNeVuXYL6jzzgkcf4Xtrs4rjbWubeCZb+pMh06K8LekSkPYS+ehiY/zGAK+s6wgj6rWL7QkxJa3n3e4psOFdapHL8jTMe9iF8WyFdtOhHFm8z3SsRlPgyusC8CHC+N7EvZTlDwzzx35plY6TGd1x6GsqSMlM59LF/+hCM03NBKu17L64NhtVYnwcJfjOEbzcW864/qpPWGJXjxyiQ7gzlMXPn3n8plrs1CBM2oPmbc1tK2To9s+9b5lmCf8hbP+9Vapsog7bpLb+ADhjJRw3YKMtneXQ4sXdiAAW3H8rcW5OrdKVlxM2qJSIjrycIafhW9VP0KXHN99H1EKT92z0zw+id2YWltNz8t/BO9RynJ6AzPDKnk758BjrrqBrkD9XKLxdzaO7+sgY+bXdOfA+wnkDviFl/KH8Vo3fSgtQGs92/5BsnjHQ4kwswnpIRgKZUEAoeqjtH8BleL77PY3ZGjj/cpJzpsUIu4PSxLY3HB2Eeyv6WNbjaV6pKf+ZZj5yqX7Yp0dZM/sF0U6Fr2Cs9m5ALIjovS6uyqVHNqv3nwjaPM=',
      sshkey_type => 'rsa',
      uid         => 1010;

  }
}
