[
    {
        :email => "josetonyp@latizana.com",
         :name => "Jose",
        :admin => true
    },
        {
        :email => "juju@juju.com",
         :name => "Juju",
        :admin => false
    },
        {
        :email => "juju@juju.com",
         :name => "Juju",
        :admin => true
    },
        {
        :email => "masako@masako.com",
         :name => "Masako",
        :admin => false
    },
        {
        :email => "noriko@noriko.com",
         :name => "Noriko",
        :admin => false
    },
        {
        :email => "chiyomi@chiyomi.com",
         :name => "Chiyomi",
        :admin => false
    },
        {
        :email => "jose@jose.com",
         :name => "Jose",
        :admin => true
    },
        {
        :email => "sese@sese.com",
         :name => "Sese",
        :admin => false
    },
        {
        :email => "fujibe@fujibe.com",
         :name => "Fujibe",
        :admin => false
    },
        {
        :email => "asa@asa.com",
         :name => "Asa",
        :admin => false
    },
    {
        :email => "satoko@satoko.com",
         :name => "Satoko",
        :admin => false
    },
    {
        :email => "hiroko@hiroko.com",
         :name => "Hiroko",
        :admin => false
    },
    {
        :email => "makoto@makoto.com",
         :name => "Inagawa",
        :admin => false
    }
].each do |user_data|
  User.create(user_data)
end
