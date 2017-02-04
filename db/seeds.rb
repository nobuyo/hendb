require "date"
# create admin
admin = User.new(email: 'admin@hendb.com', is_admin: true)
admin.encrypt_password('password')
admin.save!

s1 = Date.parse("2017/02/03")
s2 = Date.parse("2017/12/31")

(1..10).each do |a|
  univ = Univ.new(name: "Univ#{a}",
    dept: "Dept#{a}",
    pref: "Pref#{a}",
    deviation_value: Random.rand(35..65),
    exam_date: Random.rand(s1 .. s2),
    result_date: Random.rand(s1 .. s2),
    affirmation_date: Random.rand(s1 .. s2),
    document_url: 'https://github.com',
    remark: "univ univ univ")
    3.times do
      univ.exams.build(subject: Random.rand(1..9))
    end
    univ.save!
end